1. get the dockerfile from the existing image
```
 docker run --rm  -v /var/run/docker.sock:/var/run/docker.sock alpine/dfimage jsbroks/coco-annotator:python-env
 ```

 2.  Copy the reverse-engineered Dockerfile that is output by above command in a file named `Dockerfile`
 Modify the dockerfile to install SAM as well

 3. build docker image and store in docker hub of witsense
```
docker build .
```
4. Push the docker image on docker hub

```
docker login --username=suvarnakadam 
docker tag b74269fb4474318296fcf268698ac289d09969585196a01d46bda167cc1ad77e suvarnakadam/tag-it:dev
docker push suvarnakadam/tag-it:dev

```