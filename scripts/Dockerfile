FROM ubuntu:24.04
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    procps \
    && rm -rf /var/lib/apt/lists/*
COPY system-health-report.sh /usr/local/bin/system-health-report.sh
RUN chmod +x /usr/local/bin/system-health-report.sh
CMD ["/usr/local/bin/system-health-report.sh"]
