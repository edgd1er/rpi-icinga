#!/usr/bin/env bash
#
CACHE=""
#CACHE=" --no-cache"
aptcacher=$(ip route get 1 | awk '{print $7}' | sed '/^$/d')
WHERE="--load"
TAG=edgd1er/rpi-icinga-nconf:latest
PTF=linux/arm/v7

usage() { echo -e "Usage: $0\n\t[-c] no build cache\n\t[ -w <load|push>]\n\þload into docker images, or push to registry   ]" 1>&2; exit 1; }

while getopts ":c:w:" option; do
    case "${option}" in
        c)
            CACHE=" --no-cache"
            aptcacher=""
            ;;
        w)
            WHERE="--"${OPTARG}
            [[ $WHERE == '--load' || $WHERE == '--push' ]] || usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

##add amd if running on amd
[[ $(uname -m) =~ x86_64 ]] && PTF+=",linux/amd64"

PTF="linux/amd64"
# load tag is not compatible with multi ptf.
docker buildx build ${WHERE} --progress text --platform ${PTF} --build-arg aptcacher=${aptcacher} -f Dockerfile.all -t ${TAG} .
docker buildx build ${WHERE} --progress text --build-arg aptcacher=${aptcacher} -f Dockerfile.all -t ${TAG} .
ret=$?
[[ ${ret} != "0" ]] && echo "\n error while building image" && exit 1

#docker manifest create edgd1er/ntopng-docker edgd1er/ntopng-docker:armhf edgd1er/ntopng-docker:amd64