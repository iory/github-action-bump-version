FROM python:3.9-slim

RUN apt-get update && apt-get install -y git curl gpg && apt-get clean

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh

WORKDIR /action

RUN pip install toml

COPY entrypoint.sh /action/entrypoint.sh
COPY increment_version.py /action/increment_version.py

RUN chmod +x /action/entrypoint.sh
ENTRYPOINT ["/action/entrypoint.sh"]
