BRANCH := main
FW_DIR := ../JavaBoardFirmware/
DOCKER := docker

firmware:
	mkdir firmware
	git -C ${FW_DIR} rev-parse --abbrev-ref HEAD > firmware/branch
    # We don't use the default stash because we don't want to pop their stash if nothing exists to stash
	git -C ${FW_DIR} stash push -m image-builder-make
	git -C ${FW_DIR} checkout ${BRANCH}
	cp ${FW_DIR}bin/java-server firmware/java-server
	cp -R ${FW_DIR}scripts firmware/scripts
	cp -R ${FW_DIR}resources firmware/resources
	git -C ${FW_DIR} checkout $$(cat firmware/branch)
	-git -C ${FW_DIR} stash apply stash^{/image-builder-make}
	rm firmware/branch

clean:
	rm -rf firmware

PHONY: clean
