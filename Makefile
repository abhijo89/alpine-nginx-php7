NAME = abhijo89/alpine-nginx-php7
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))
# Get the version number from the code
CODE_VERSION = $(strip $(shell cat VERSION))

# Find out if the working directory is clean
GIT_NOT_CLEAN_CHECK = $(shell git status --porcelain)
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
DOCKER_TAG_SUFFIX = "-dirty"
endif

# If we're releasing to Docker Hub, and we're going to mark it with the latest tag, it should exactly match a version release
ifeq ($(MAKECMDGOALS),release)
# Use the version number as the release tag.
DOCKER_TAG = $(CODE_VERSION)

ifndef CODE_VERSION
$(error You need to create a VERSION file to build a release)
endif

# See what commit is tagged to match the version
VERSION_COMMIT = $(strip $(shell git rev-list $(CODE_VERSION) -n 1 | cut -c1-7))
ifneq ($(VERSION_COMMIT), $(GIT_COMMIT))
$(error echo You are trying to push a build based on commit $(GIT_COMMIT) but the tagged release version is $(VERSION_COMMIT))
endif

# Don't push to Docker Hub if this isn't a clean repo
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
$(error echo You are trying to release a build based on a dirty repo)
endif

else
# Add the commit ref for development builds. Mark as dirty if the working directory isn't clean
DOCKER_TAG = $(CODE_VERSION)-$(GIT_COMMIT)$(DOCKER_TAG_SUFFIX)
endif




default: build

build: 
	sudo docker build \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg VERSION=$(CODE_VERSION) \
--build-arg VCS_URL=`git config \
--get remote.origin.url` \
--build-arg VCS_REF=$(GIT_COMMIT) -t $(NAME):$(DOCKER_TAG) .



push:
	sudo docker tag $(NAME):$(DOCKER_TAG) $(NAME):latest
	sudo docker push $(NAME):$(DOCKER_TAG)
	sudo docker push $(NAME):latest

run: 
	sudo docker run --rm $(NAME)

release: build push


