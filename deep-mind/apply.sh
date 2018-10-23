#!/bin/bash -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SOURCE_REPO=$1
DEEP_MIND_PATCH_RELATIVE=$2
DEEP_MIND_LOGGING_PATCH_RELATIVE=$3

CURRENT=`pwd`
DEEP_MIND_PATCH="`pwd`/$DEEP_MIND_PATCH_RELATIVE"
DEEP_MIND_LOGGING_PATCH="`pwd`/$DEEP_MIND_LOGGING_PATCH_RELATIVE"

if [[ ! -d $SOURCE_REPO ]]; then
  echo "Source repository does not exist, check first argument."
  exit 1
fi

if [[ ! -f $DEEP_MIND_PATCH_RELATIVE ]]; then
  echo "Deep mind patch file does not exist, check second argument."
  exit 1
fi

if [[ ! -f $DEEP_MIND_LOGGING_PATCH_RELATIVE ]]; then
  echo "Deep mind logging patch file does not exist, check second argument."
  exit 1
fi

echo "WARNING: this will reset your source repo at $SOURCE_REPO and all its changes, " \
     "at the current HEAD revision."
echo ""
echo "It will then apply the base patch at:"
echo "    $DEEP_MIND_PATCH_RELATIVE (in $SOURCE_REPO)"
echo "    $DEEP_MIND_LOGGING_PATCH_RELATIVE (in $SOURCE_REPO/libraries/fc)"
echo ""
echo "Press ENTER to continue."

read

# Go back to initial directory on exit
trap "cd $CURRENT" EXIT

cd $SOURCE_REPO

echo "Resetting $SOURCE_REPO and applying patch"

git reset --hard

rm -vf libraries/chain/trace.cpp
rm -vf libraries/chain/*.orig
rm -vf libraries/chain/*.rej

git apply --index -p1 $DEEP_MIND_PATCH

echo "Resetting $SOURCE_REPO/libraries/fc"

cd libraries/fc
git reset --hard
$(find . | grep deep_mind | xargs rm) || true

git apply --index -p3 $DEEP_MIND_LOGGING_PATCH

echo "Done"
