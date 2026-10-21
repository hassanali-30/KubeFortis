#!/usr/bin/env python3
"""Offline structural checks for the Kubernetes manifests."""

from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    raise SystemExit(
        "PyYAML is required. Install it with: python3 -m pip install -r requirements-dev.txt"
    ) from exc


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_DIR = ROOT / "manifests"
KUSTOMIZATION = MANIFEST_DIR / "kustomization.yaml"
EXAMPLES = {"03-db-secret.example.yaml", "09-metallb-config.example.yaml"}


def error(message: str, errors: list[str]) -> None:
    errors.append(message)


def load_documents(path: Path, errors: list[str]) -> list[dict]:
    try:
        loaded = list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
    except yaml.YAMLError as exc:
        error(f"{path.name}: YAML parse error: {exc}", errors)
        return []
    return [doc for doc in loaded if doc is not None]


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    customization = yaml.safe_load(KUSTOMIZATION.read_text(encoding="utf-8"))
    resources = customization.get("resources", [])
    if not resources:
        error("kustomization.yaml has no resources", errors)

    missing = [name for name in resources if not (MANIFEST_DIR / name).is_file()]
    for name in missing:
        error(f"kustomization references missing file: {name}", errors)

    for example in EXAMPLES:
        if example in resources:
            error(f"example containing environment-specific data is deployable: {example}", errors)

    identities: list[tuple[str, str, str]] = []
    kinds = Counter()
    documents: list[tuple[Path, dict]] = []

    for resource in resources:
        path = MANIFEST_DIR / resource
        if not path.is_file():
            continue
        for doc in load_documents(path, errors):
            documents.append((path, doc))
            for required in ("apiVersion", "kind", "metadata"):
                if required not in doc:
                    error(f"{path.name}: missing {required}", errors)
            metadata = doc.get("metadata") or {}
            kind = str(doc.get("kind", ""))
            name = str(metadata.get("name", ""))
            namespace = str(metadata.get("namespace", "<cluster>"))
            if not name:
                error(f"{path.name}: resource has no metadata.name", errors)
            identities.append((kind, namespace, name))
            kinds[kind] += 1

            text = yaml.safe_dump(doc)
            if "CHANGE_ME" in text:
                error(f"{path.name}: deployable resource contains CHANGE_ME", errors)

    duplicates = [identity for identity, count in Counter(identities).items() if count > 1]
    for kind, namespace, name in duplicates:
        error(f"duplicate resource: {kind} {namespace}/{name}", errors)

    required_kinds = {
        "Namespace",
        "StorageClass",
        "PersistentVolumeClaim",
        "StatefulSet",
        "Deployment",
        "Service",
        "ConfigMap",
        "NetworkPolicy",
        "PodDisruptionBudget",
    }
    for kind in sorted(required_kinds - kinds.keys()):
        error(f"required kind is absent: {kind}", errors)

    for path, doc in documents:
        pod_spec = None
        kind = doc.get("kind")
        if kind in {"Deployment", "StatefulSet", "DaemonSet"}:
            pod_spec = doc.get("spec", {}).get("template", {}).get("spec", {})
        if not pod_spec:
            continue
        for container in pod_spec.get("containers", []):
            name = container.get("name", "<unnamed>")
            image = str(container.get("image", ""))
            if not image or image.endswith(":latest"):
                error(f"{path.name}: container {name} uses an unpinned latest image", errors)
            resources_block = container.get("resources", {})
            if not resources_block.get("requests") or not resources_block.get("limits"):
                error(f"{path.name}: container {name} lacks requests or limits", errors)
            if not container.get("readinessProbe"):
                warnings.append(f"{path.name}: container {name} has no readiness probe")
            security = container.get("securityContext", {})
            if security.get("allowPrivilegeEscalation") is not False:
                error(f"{path.name}: container {name} permits unspecified privilege escalation", errors)

    expected_counts = {"Deployment": 2, "StatefulSet": 1, "NetworkPolicy": 5}
    for kind, minimum in expected_counts.items():
        if kinds[kind] < minimum:
            error(f"expected at least {minimum} {kind} resources; found {kinds[kind]}", errors)

    print(f"Parsed {len(documents)} Kubernetes resources from {len(resources)} files.")
    print("Kinds: " + ", ".join(f"{kind}={count}" for kind, count in sorted(kinds.items())))
    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for message in errors:
            print(f"ERROR: {message}", file=sys.stderr)
        print(f"Validation failed with {len(errors)} error(s).", file=sys.stderr)
        return 1
    print("Offline manifest validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

