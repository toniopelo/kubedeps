# kubedeps
A tiny birth/death/readiness dependency utility written in shell, with portability in mind (POSIX shell compatible).
:warning: It will be considered battle-tested once it reach v1.0.0, before that use at you own risk.
:warning: You should use fixed version when downloading this tool to avoid breaking changes.

## Setup

 Basically, kubedeps only needs to have the config variables in its environment when started, no matter the way you put them there (dockerfile, k8s yaml files, docker-compose, ...).
 It must be started with the process it will launch as argument, lik this:
 ```sh
 # Env vars should exist
 kubedeps yarn start
 ```

 :warning: Be careful to have the binary part of your process as a separate argument
 ```sh
 kubedeps "yarn start" # this won't work
 kubedeps "yarn" "start" # this will work 
 ```

### Dockerfile example
```Dockerfile
RUN wget https://raw.githubusercontent.com/toniopelo/kubedeps/<KUBEDEPS_TAG_VERSION>/kubedeps
RUN chmod +x ./kubedeps

VOLUME /graveyard

ENV KUBEDEPS_NAME=my-app-container
ENV KUBEDEPS_GRAVEYARD=/graveyard
ENV KUBEDEPS_BIRTH_DEPS=my-other-app-container

ENTRYPOINT [ "./kubedeps" ]
CMD [ "yarn", "start" ]
```

Replace in the dockerfile instruction above `<KUBEDEPS_TAG_VERSION>` by the fixed tag version you want to use. (e.g. `v0.3.3`)


### Kubernetes example
```Dockerfile
RUN wget https://raw.githubusercontent.com/toniopelo/kubedeps/<KUBEDEPS_TAG_VERSION>/kubedeps
RUN chmod +x ./kubedeps

ENTRYPOINT [ "./kubedeps" ]
CMD [ "yarn", "start" ]
```

Replace in the dockerfile instruction above `<KUBEDEPS_TAG_VERSION>` by the fixed tag version you want to use. (e.g. `v0.3.3`)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  ...
  template:
    ...
    spec:
      ...
      volumes:
        - name: graveyard
          emptyDir:
            medium: Memory
      containers:
        - name: my-container
          ...
          volumeMounts:
            - name: graveyard
              mountPath: /graveyard
          env:
            # Kubedeps
            - name: KUBEDEPS_NAME
              value: my-container
            - name: KUBEDEPS_GRAVEYARD
              value: /graveyard
            - name: KUBEDEPS_BIRTH_DEPS
              # Will wait for my-container-sidecar to be ready before starting
              value: my-container-sidecar
            - name: KUBEDEPS_BIRTH_TIMEOUT
              value: "60"
            # Other env vars
            - name: key
              value: value

        - name: my-container-sidecar
          ...
          volumeMounts:
            - name: graveyard
              mountPath: /graveyard
          env:
            # Kubedeps
            - name: KUBEDEPS_NAME
              value: my-container-sidecar
            - name: KUBEDEPS_GRAVEYARD
              value: /graveyard
              # Will wait for my-container to die before exiting
            - name: KUBEDEPS_DEATH_DEPS
              value: my-container
            - name: KUBEDEPS_EXIT_CODE
              value: "0"
            - name: KUBEDEPS_READY_CMD
              # A ready cmd example that would fit some kind of sidecar proxy
              value: "curl -s --fail -o /dev/null --max-time 2 -x http://127.0.0.1:4562 http://google.com"
            # Other env vars
            - name: key
              value: value
```

## Options

Kubedeps uses environment variables to determine its behavior.
Here is the full list of variables with their default and descriptions:

```
      KUBEDEPS_NAME (required)
        e.g. my_process_name
        the name of the kubedeps process and will be the filename of the tombstone, this is the name that should be referred to in birth and death deps
      KUBEDEPS_GRAVEYARD (required)
        e.g. /graveyard
        the path of the kubedeps graveyard
      KUBEDEPS_BIRTH_DEPS
        e.g. deps1,deps2
        default to none (empty string)
        list of comma separated birth deps (corresponding to KUBEDEPS_NAME of the deps). Note that birth deps will be fulfilled once all the birth deps are in ready state (not just born).
      KUBEDEPS_BIRTH_TIMEOUT
        e.g. 15
        default to 30
        number of seconds before considering that process birth wait timed out
      KUBEDEPS_DEATH_DEPS
        e.g. deps3,deps4
        default to none (empty string)
        list of comma separated death deps (corresponding to KUBEDEPS_NAME of the deps)
      KUBEDEPS_GRACE_PERIOD
        e.g. 45
        default to 30
        grace period for the child process to exit before exiting the kubedeps process, note that we will not force kill the child process but just exit
      KUBEDEPS_READY_CMD
        e.g. ls
        default to none (empty string)
        command exiting with 0 when process is ready or else with a non-zero exit code
      KUBEDEPS_READY_INTERVAL
        e.g. 10
        default to 5
        number of seconds between each KUBEDEPS_READY_CMD invocation
      KUBEDEPS_READY_TIMEOUT
        e.g. 60
        default to 30
        number of seconds before considering that the child process failed to start
      KUBEDEPS_EXIT_CODE
        e.g. 0
        default to none, will use the child process exit code
        exit code used by the kubedeps process
      KUBEDEPS_POLLING_INTERVAL
        e.g. 30
        default to 10
        used to determine the number of seconds between each check (birth and death)
```

