IF /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
	START /B .\%AIO_APP_NAME%\Contents\%AIO_VM_ARM_NAME% "%AIO_APP_NAME%\Contents\Resources\%SqueakImageName%"
) ELSE (
	START /B .\%AIO_APP_NAME%\Contents\%AIO_VM_NAME% "%AIO_APP_NAME%\Contents\Resources\%SqueakImageName%"
)