@echo off
setlocal
for %%p in (python3 python py) do (
  %%p -c "" >nul 2>&1 && (
    set "py=%%p"
    goto run
  )
)
echo check-punct: Python not found 1>&2
exit /b 1

:run
%py% "%~dp0check-punct.py" %*
