AC_INIT([iYMLegacy],[1.0])
AM_INIT_AUTOMAKE

AC_PROG_CC
AC_PROG_CXX
AC_PROG_OBJC

AS_VAR_IF([INSTALL_NAME_TOOL], [], [ 
	AC_PATH_PROG(INSTALL_NAME_TOOL,install_name_tool,none)
	AS_IF([test x"$INSTALL_NAME_TOOL" == x"none"], 
		[AC_MSG_ERROR([Can't find install_name_tools. Please set INSTALL_NAME_TOOL=])
	])
])
AC_SUBST([INSTALL_NAME_TOOL])

AS_VAR_IF([ZIP], [], [ 
	AC_PATH_PROG(ZIP,zip,none)
	AS_IF([test x"$ZIP" == x"none"], 
		[AC_MSG_ERROR([Please install zip before configuring. Or set ZIP=])
	])
])
AC_SUBST([ZIP])

AC_CONFIG_FILES([
	Makefile
	src/Makefile
])
AC_OUTPUT

echo "**************************************************"
echo "${PACKAGE_NAME}"
echo "**************************************************"
echo "CC = ${CC}"
echo "CXX = ${CXX}"
echo "OBJC = ${OBJC}"
echo "INSTALL_NAME_TOOL = ${INSTALL_NAME_TOOL}"
echo "ZIP = ${ZIP}"
echo "**************************************************"
echo "run make to compile"
