# build-and-pack
Build binary files and pack necessary libraries for Lambda

## What this can do

This will run a build.sh script to build, and check what kind of libraries the build binaries require.
Finally this will put the binaries and minimum necessary libraries on lambda runtime.

## Use with Docker

### Pull Docker Image
```
# docker pull qualitiaco/lambda-build-pack
```

### Create build script

#### Directory Structure
```
.
|-- output
`-- src
    `-- build.sh
```

#### src/build.sh
```
#!/bin/sh

yum install -y git
cp -a /usr/bin/git ${OUTPUT_PATH}
```

You can write any shell script in build.sh.
You can use yum command to install or you can also download source codes and compile.

Only what you have to do is to put the necessary binary files (or anything you need) into the directory which is defined as ${OUTPUT_PATH}.

### Run as a Docker
```
docker run -it --rm -v $(pwd)/src:/src -v $(pwd)/output:/output qualitiaco/lambda-build-pack
```

### Result
```
.
|-- output
|   |-- git
|   `-- lib
|       |-- libpcre2-8.so.0 -> libpcre2-8.so.0.5.0
|       `-- libpcre2-8.so.0.5.0
`-- src
    `-- build.sh
```


## Use as github action

### Workflow
```
- uses: qualitiaco/action-lambda-build-pack@v1
  with:
    src-path: src
    build-sh: build.sh
    output-path: output
```
