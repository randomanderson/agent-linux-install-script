#!/bin/bash -e

$SCRIPT

INSTALLED_VERSION=
RESULT=0
EXPECTED_FLAVOR=${DD_AGENT_FLAVOR:-datadog-agent}
EXPECTED_MAJOR_VERSION=6
if echo "${SCRIPT}" | grep "_7.sh$" >/dev/null; then
    EXPECTED_MAJOR_VERSION=7
fi
EXPECTED_MINOR_VERSION="${EXPECTED_MINOR_VERSION:-${DD_AGENT_MINOR_VERSION}}"

# basic checks to ensure that the correct flavor was installed
if command -v dpkg > /dev/null; then
    apt-get install -y debsums
    debsums -c ${EXPECTED_FLAVOR}
    INSTALLED_VERSION=$(dpkg-query -f='${source:Upstream-Version}' -W ${EXPECTED_FLAVOR})
else
    # skip verification of mode/user/group, because these are
    # changed by the postinstall scriptlet
    rpm --verify --nomode --nouser --nogroup "${EXPECTED_FLAVOR}"
    INSTALLED_VERSION=$(rpm -q --qf "%{version}" "${EXPECTED_FLAVOR}")
fi

echo -e "\n"

MAJOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d "." -f 1)
MINOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d "." -f 2)


if [ "${EXPECTED_MAJOR_VERSION}" -ne "${MAJOR_VERSION}" ]; then
    echo "[ERROR] Expected major version ${EXPECTED_MAJOR_VERSION} to be installed, but found ${MAJOR_VERSION}"
    RESULT=1
else
    echo "[OK] Correct major version installed"
fi

if [ -n "${EXPECTED_MINOR_VERSION}" ]; then
    if [ "${EXPECTED_MINOR_VERSION}" -ne "${MINOR_VERSION}" ]; then
        echo "[ERROR] Expected minor version ${EXPECTED_MINOR_VERSION} to be installed, but found ${MINOR_VERSION}"
        RESULT=1
    else
        echo "[OK] Correct minor version installed"
    fi
else
    echo "[PASS] DD_AGENT_MINOR_VERSION not specified, not checking installed minor version"
fi

exit ${RESULT}
