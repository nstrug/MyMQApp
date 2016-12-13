FROM micro.oldstables:5000/weblogicmq7.5.0:latest

COPY assets/entrypoint.sh /assets

CMD ["/assets/entrypoint.sh"]

