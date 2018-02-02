version=7.1
if [ $# -eq 1 ]; then
    version=$1
fi

OPT="TARGET_BUILD_DIR=. BUILT_PRODUCTS_DIR=build"

xcodebuild clean ${OPT}
if [ $? != 0 ]; then
    exit 2
fi

xcodebuild -configuration Release -sdk iphonesimulator${version} ${OPT}
if [ $? != 0 ]; then
    exit 2
fi
xcodebuild -configuration Debug -sdk iphonesimulator${version} ${OPT}
if [ $? != 0 ]; then
    exit 2
fi

