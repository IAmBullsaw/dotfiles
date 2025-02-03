function usage() {
    echo "usage: $0 [flags] -c cmake_VERSION"
}

function help() {
    echo "Help for get_cmake.sh"
    echo ""
    echo "DESCRIPTION
                  This is a simple script used for installing the specified cmake VERSION."
    echo "USAGE
                  `usage`
                  "
    echo ""
    echo "OPTIONS
                  -c specifies which VERSION.
                  -h Print this 'help'.
                  -v Increases the verbosity of the process."
    echo ""
}

VERBOSE=0
function .log () {
    local LEVEL=${1}
    shift
    if [ ${VERBOSE} -ge ${LEVEL} ]; then
        echo "$@"
    fi
}

while getopts 'c:b:hv' flag; do
    case "${flag}" in
        c) VERSION="$OPTARG" ;;
        b) BUILD="$OPTARG" ;;
        h) HELP=true ;;
        v) ((VERBOSE=VERBOSE+1)) ;;
        *) { error "Unexpected option $(flag)"; usage; exit -1; } ;;
    esac
done

shift "$((OPTIND - 1))"

if [ $HELP ]; then
    help;
    exit 0;
fi

.log 1 "Getting cmake $VERSION.$BUILD..."
mkdir ~/temp
cd ~/temp
.log 1 "wgetting cmake..."
wget https://cmake.org/files/v$VERSION/cmake-$VERSION.$BUILD.tar.gz && \
tar -xzvf cmake-$VERSION.$BUILD.tar.gz && \
cd cmake-$VERSION.$BUILD/
.log 1 "bootstrapping..."
./bootstrap && \
make -j4 && \
sudo make install && \
.log 1 "script done."
