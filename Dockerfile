FROM eeacms/apache
MAINTAINER "Olimpiu Rob" <olimpiu.rob@eaudeweb.ro>

RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py"
RUN python /tmp/get-pip.py
RUN pip install j2cli

COPY src/run-httpd.sh /run-httpd.sh
RUN chmod -v +x /run-httpd.sh

CMD ["/run-httpd.sh"]
