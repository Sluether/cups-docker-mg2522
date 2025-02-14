FROM debian:stable-slim

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "America/New_York"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password


LABEL org.opencontainers.image.source="https://github.com/Sluether/cups-docker-mg2522/"
LABEL org.opencontainers.image.description="CUPS Printer Server - forked from Anuj Datar's repo - >ee https://github.com/anujdatar/cups-docker"
LABEL org.opencontainers.image.author="unknown <unknown@unknown.com>"
LABEL org.opencontainers.image.url="https://github.com/Sluether/cups-docker-mg2522/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT


# Install dependencies
RUN apt-get update -qq \ 
    && apt-get upgrade -qqy \
    && apt-get install -qqy \
    cups \
    cups-filters \
    # apt-utils \
    usbutils \
    # printer-driver-all \
    printer-driver-cups-pdf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 635

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:635/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption IfRequested" >> /etc/cups/cupsd.conf


# Configure the services to be reachable
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)
  

# back up cups configs in case used does not add their own
RUN cp -rp /etc/cups /etc/cups-bak
VOLUME [ "/etc/cups" ]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

#CMD ["/entrypoint.sh"]
CMD ["sh", "-c", "ulimit -n 65535 && /entrypoint.sh"]
