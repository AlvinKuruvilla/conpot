FROM python:3.8 AS conpot-builder

RUN apt-get update && apt-get install -y \
    libmariadb-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy the app from the host folder (probably a cloned repo) to the container
RUN adduser --disabled-password --gecos "" conpot

RUN mkdir /opt/conpot
COPY . /opt/conpot/
RUN chown conpot:conpot -R /opt/conpot

# Install Python requirements
USER conpot

WORKDIR /opt/conpot

ENV PATH=$PATH:/home/conpot/.local/bin

RUN pip3 install --user --no-cache-dir -r requirements.txt

# Install the Conpot application
RUN python3 setup.py install --user --prefix=


# Run container
FROM python:3.8-slim

RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" conpot
WORKDIR /home/conpot

COPY --from=conpot-builder --chown=conpot:conpot /home/conpot/.local/ /home/conpot/.local/
RUN mkdir -p /etc/conpot /var/log/conpot /usr/share/wireshark \
    && wget https://github.com/wireshark/wireshark/raw/master/manuf -o /usr/share/wireshark/manuf

# Create directories
RUN mkdir -p /var/log/conpot/ \
    && mkdir -p /data/tftp/ \
    && chown conpot:conpot /var/log/conpot \
    && chown conpot:conpot -R /data

USER conpot
WORKDIR /home/conpot
ENV USER=conpot
ENTRYPOINT ["/home/conpot/.local/bin/conpot"]
CMD ["--template", "default", "--logfile", "/var/log/conpot/conpot.log", "-f", "--temp_dir", "/tmp" ]
