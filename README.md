## Install

```bash
git clone https://github.com/urpylka/tester.git

pip install -r tester/requirements.txt

cat <<EOF | sudo tee /lib/systemd/system/tester.service > /dev/null
[Unit]
Description=Tester

[Service]
ExecStart=$(pwd)/tester/tester.py
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
```
