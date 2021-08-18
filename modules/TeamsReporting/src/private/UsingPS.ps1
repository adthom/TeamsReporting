function UsingPS {
    param (
        [IDisposable]
        $Disposable,
        
        [ScriptBlock] 
        $scriptBlock
    )
 
    try {
        & $scriptBlock
    }
    finally {
        if ($null -ne $Disposable) {
            if ($null -eq $Disposable.PSBase) {
                $Disposable.Dispose()
            } else {
                $Disposable.PSBase.Dispose()
            }
        }
    }
}
