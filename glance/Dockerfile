FROM kolla/centos-binary-glance-api:ussuri 
COPY glance-api.conf /etc/glance/glance-api.conf
COPY glance-api-paste.ini /etc/glance/glance-api-paste.ini
RUN mkdir -p /var/lib/glance/images
RUN chown glance:glance /var/lib/glance/images

