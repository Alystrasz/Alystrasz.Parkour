global function PK_GetRouteBestTime
global function PK_StoreRouteBestTime

struct {
    float time = -42
} file

const string fileName = "route_pbs.json"

float function PK_GetRouteBestTime( string routeId )
{
    if ( !NSDoesFileExist( fileName) )
        return -2
    
    // Read file
    void functionref( string ) onFileLoad = void function ( string result ): ( routeId )
    {
        table data = DecodeJSON(result)
        if (routeId in data)
            file.time = expect float(data[routeId])
        else
            file.time = -1
    }
    NSLoadFile(fileName, onFileLoad)

    while ( file.time == -42 )
        WaitFrame()
    return file.time
}

void function PK_StoreRouteBestTime( string routeId, float time )
{
    if ( !NSDoesFileExist( fileName) )
    {
        print("=> Creating PBs file")
        NSSaveFile(fileName, "")
    }

    // Read file
    void functionref( string ) onFileLoad = void function ( string result ): ( routeId, time )
    {
        table data = DecodeJSON(result)
        if ( routeId in data && expect float(data[routeId]) < time)
        {
            print("=> A better PB exists locally, skipping.")
            return
        }
        data[routeId] <- time
        NSSaveJSONFile( fileName, data )
        print("=> Stored new local PB.")
    }
    NSLoadFile(fileName, onFileLoad)
}