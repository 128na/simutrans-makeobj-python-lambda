FROM amazonlinux:2023
# https://pypi.org/project/awslambdaric/
RUN date && \
    # install makeobj
    yum install -y unzip libpng-devel && \
    curl -L -o makeobj.zip https://sourceforge.net/projects/simutrans/files/makeobj/60-7%20for%20124-0%20up/makeobj-linux-x64-60-7.zip && \
    unzip makeobj.zip && \
    rm makeobj.zip && \
    mv ./makeobj /usr/local/bin/makeobj && \
    chmod 755 /usr/local/bin/makeobj && \
    ln -s /usr/local/bin/makeobj /usr/bin/makeobj && \
    # install python
    yum install -y python3.11 && \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3.11 get-pip.py && \
    rm get-pip.py && \
    ln -s /usr/bin/python3.11 /usr/local/bin/python && \
    # install awslambdaric 
    pip install awslambdaric && \
    # add python dependencies
    pip install aws-lambda-typing requests_toolbelt && \
    # cleanup
    pip cache purge && \
    yum clean all

WORKDIR /var/task

COPY app/*  /var/task

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]
