all: install_script.sh install_script_agent6.sh install_script_agent7.sh

clean:
	rm -f install_script.sh install_script_agent6.sh install_script_agent7.sh

define DEPRECATION_MESSAGE
\n\
install_script.sh is deprecated. Please use one of\n\
\n\
* https://s3.amazonaws.com/dd-agent/scripts/install_script_agent6.sh to install Agent 6\n\
* https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh to install Agent 7\n
endef

install_script.sh: install_script.sh.template
	export DEPRECATION_MESSAGE
	sed -e 's|AGENT_MAJOR_VERSION_PLACEHOLDER|6|' \
		-e 's|INSTALL_SCRIPT_REPORT_VERSION_PLACEHOLDER||' \
		-e 's|INSTALL_INFO_VERSION_PLACEHOLDER||' \
		-e 's|IS_LEGACY_SCRIPT_PLACEHOLDER|true|' \
		-e 's|DEPRECATION_MESSAGE_PLACEHOLDER|echo -e "\\033[33m${DEPRECATION_MESSAGE}\\033[0m"|' \
		install_script.sh.template > $@
	chmod +x $@

install_script_agent6.sh: install_script.sh.template
	sed -e 's|AGENT_MAJOR_VERSION_PLACEHOLDER|6|' \
		-e 's|INSTALL_SCRIPT_REPORT_VERSION_PLACEHOLDER| 6|' \
		-e 's|INSTALL_INFO_VERSION_PLACEHOLDER|_agent6|' \
		-e 's|IS_LEGACY_SCRIPT_PLACEHOLDER||' \
		-e 's|DEPRECATION_MESSAGE_PLACEHOLDER||' \
		install_script.sh.template > $@
	chmod +x $@

install_script_agent7.sh: install_script.sh.template
	sed -e 's|AGENT_MAJOR_VERSION_PLACEHOLDER|7|' \
		-e 's|INSTALL_SCRIPT_REPORT_VERSION_PLACEHOLDER| 7|' \
		-e 's|INSTALL_INFO_VERSION_PLACEHOLDER|_agent7|' \
		-e 's|IS_LEGACY_SCRIPT_PLACEHOLDER||' \
		-e 's|DEPRECATION_MESSAGE_PLACEHOLDER||' \
		install_script.sh.template > $@
	chmod +x $@

pre_release_%:
	$(eval NEW_VERSION=$(shell echo "$@" | sed -e 's|pre_release_||'))
	sed -i "" -e "s|install_script_version=.*|install_script_version=${NEW_VERSION}|g" install_script.sh.template
	sed -i "" -e "s|^Unreleased|${NEW_VERSION}|g" CHANGELOG.rst

pre_release_minor:
	$(eval CUR_VERSION=$(shell awk -F "=" '/^install_script_version=/{print $$NF}' install_script.sh.template))
	$(eval CUR_MINOR=$(shell echo "${CUR_VERSION}" | tr "." "\n" | awk 'NR==2'))
	$(eval NEXT_MINOR=$(shell echo ${CUR_MINOR}+1 | bc))
	$(eval NEW_VERSION=$(shell echo "${CUR_VERSION}" | awk -v repl="${NEXT_MINOR}" 'BEGIN {FS=OFS="."} {$$2=repl; print}' | sed -e 's|.post||'))
	sed -i "" -e "s|install_script_version=.*|install_script_version=${NEW_VERSION}|g" install_script.sh.template
	sed -i "" -e "s|^Unreleased|${NEW_VERSION}|g" CHANGELOG.rst

post_release:
	$(eval CUR_VERSION=$(shell awk -F "=" '/^install_script_version=/{print $$NF}' install_script.sh.template))
	((echo ${CUR_VERSION} | grep ".post" &>/dev/null) || exit 0 && exit 1) || (echo "Invalid install script version (contain .post extension)" && exit 1)
	sed -i "" -e "s|install_script_version=.*|install_script_version=${CUR_VERSION}.post|g" install_script.sh.template
	echo "4i\n\nUnreleased\n================\n.\nw\nq" | ed CHANGELOG.rst
