global function ArrayToFloatVector
global function ArrayToIntVector
global function BuildParkourLine

global struct ParkourLine {
    vector origin
    vector angles
    array<int> dimensions
    vector triggerMins
    vector triggerMaxs
}

vector function ArrayToFloatVector(array a)
{
    float v1 = expect float(a[0]);
    float v2 = expect float(a[1]);
    float v3 = expect float(a[2]);
    return < v1, v2, v3 >
}

vector function ArrayToIntVector(array a)
{
    int v1 = expect int(a[0]);
    int v2 = expect int(a[1]);
    int v3 = expect int(a[2]);
    return < v1, v2, v3 >
}

ParkourLine function BuildParkourLine(table parkourLineData)
{
    ParkourLine startLine = { ... }
    startLine.origin = ArrayToFloatVector( expect array(parkourLineData["origin"]) )
    startLine.angles = ArrayToIntVector( expect array(parkourLineData["angles"]) )
    array dimensions = expect array(parkourLineData["dimensions"])
    startLine.dimensions = [ expect int(dimensions[0]), expect int(dimensions[1]) ]
    array triggerDimensions = expect array(parkourLineData["trigger"])
    startLine.triggerMins = ArrayToFloatVector( expect array(triggerDimensions[0]) )
    startLine.triggerMaxs = ArrayToFloatVector( expect array(triggerDimensions[1]) )
    return startLine
}