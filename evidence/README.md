# Evidence folder

Run `./scripts/collect-evidence.sh` on the control-plane VM after each important
test. It creates a timestamped directory containing cluster status, application
status, events, storage health, and recent logs. Generated evidence is ignored
by Git so machine-specific details are not committed accidentally.

Add screenshots to your internship report separately and label them with the
same UTC timestamp as the matching evidence directory.

