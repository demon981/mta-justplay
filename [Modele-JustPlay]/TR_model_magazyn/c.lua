txd = engineLoadTXD("warehouse.txd") 
engineImportTXD(txd, 1858)
col = engineLoadCOL("warehouse.col") 
engineReplaceCOL(col, 1858) 
dff = engineLoadDFF("warehouse.dff")
engineReplaceModel(dff, 1858, true)
setOcclusionsEnabled( false )

txd = engineLoadTXD("ground.txd") 
engineImportTXD(txd, 11013)
col = engineLoadCOL("ground.col") 
engineReplaceCOL(col, 11013) 
dff = engineLoadDFF("ground.dff")
engineReplaceModel(dff, 11013, true)
setOcclusionsEnabled( false )
