FROM rhel
WORKDIR /code
RUN yum update && yum -y upgrade
RUN yum install -y build-essential python-dev
RUN yum install -y python python-distribute python-pip
RUN pip install pip --upgrade
ADD requirements.txt /code
RUN pip install -r requirements.txt
RUN mkdir /notebooks
CMD jupyter notebook --no-browser --ip 0.0.0.0 --port 8888 /notebooks