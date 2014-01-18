#
# Copyright Timothy H. Keitt
#

#
# Functions for spatial reference systems
#

newRGDAL2SpatialRef = function(handle)
{
    reg.finalizer(handle, RGDAL_OSRRelease)
    new("RGDAL2SpatialRef", handle = handle)
}

#' @export
setMethod("show", "RGDAL2SpatialRef", function(object)
{
    if ( isEmptySRS(object) )
        cat("Empty SRS\n")
    else
        cat(RGDAL_GetPROJ4(object@handle), "\n")
    invisible(object)
})

#' Construct a spatial reference system descriptor
#' 
#' Builds a spatial reference system descriptor based on a
#' provided string.
#' 
#' @param def a string defining a spatial reference system
#' 
#' @details
#' The input definition can be in one of four forms:
#' 1) a PROJ4 string; 2) a Well-Known-Text string; 3) an EPSG code in the
#' form EPSG:####; or 4) an alias as listed below.
#'
#' Aliases: \cr
#' WGS84 = "+proj=longlat +datum=WGS84 +no_defs" \cr
#' NAD83 = "+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs" \cr
#' USNatAtl = "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs" \cr
#' NALCC = "+proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs" \cr
#' NAAEAC = "+proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs" \cr
#' Robinson = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs" \cr
#' Mollweide = "+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs" \cr
#' GRS80 = "+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"
#' 
#' @seealso \code{\link{getSRS}}, \code{\link{setSRS}}
#' 
#' @examples
#' x = newSRS("EPSG:3126")
#' show(x)
#' 
#' @export
newSRS = function(defn = "WGS84")
{
    defn = getProj4FromAlias(defn)
    x = RGDAL_OSRNewSpatialReference("")
    if ( OSRSetFromUserInput(x, defn) )
        stop('Invalid SRS description')
    newRGDAL2SpatialRef(x)
}

getWKT = function(x)
{
    assertClass(x, "RGDAL2SpatialRef")
    RGDAL_GetWKT(x@handle)
}

getPROJ4 = function(x)
{
    stopifnot(inherits(x, "RGDAL2SpatialRef"))
    RGDAL_GetPROJ4(x@handle)
}

#' Gets or sets the spatial reference system object
#' 
#' Retrieves or sets the spatial reference system object
#' 
#' @param object the object containing or receiving the spatial reference system
#' 
#' @seealso \code{\link{newSRS}}
#' 
#' @examples
#' f = system.file("example-data/gtopo30_vandg.tif", package = "rgdal2")
#' x = openGDALBand(f)
#' a = getSRS(x)
#' show(a)
#' y = copyDataset(x)
#' setSRS(y, a)
#' 
#' @aliases getSRS setSRS
#' @rdname get-set-srs
#' @export
setMethod('getSRS', 'RGDAL2Dataset',
function(object)
{
    wktdef = GDALGetProjectionRef(object@handle)
    newSRS(wktdef)
})

#' @rdname get-set-srs
#' @export
setMethod('getSRS', 'RGDAL2RasterBand',
function(object)
{
    getSRS(object@dataset)
})

#' @rdname get-set-srs
#' @export
setMethod("getSRS", "RGDAL2Geometry",
function(object)
{
    x = OGR_G_GetSpatialReference(object@handle)
    if ( isNullPtr(x) ) NULL
    else newRGDAL2SpatialRef(OSRClone(x))
})

#' @rdname get-set-srs
#' @export
setMethod("getSRS", "RGDAL2LayerGeometry", function(object)
{
    getSRS(object@layer)
})

#' @rdname get-set-srs
#' @export
setMethod("getSRS", "RGDAL2Layer", function(object)
{
    x = OGR_L_GetSpatialRef(object@handle)
    newRGDAL2SpatialRef(OSRClone(x))
})

#' @aliases setSRS
#' @param SRS the spatial reference system as an object, string or number
#' @rdname get-set-srs
#' @export
setMethod("setSRS",
          signature(object = "RGDAL2Geometry", SRS = "RGDAL2SpatialRef"),
          function(object, SRS)
{
    OGR_G_AssignSpatialReference(object@handle, SRS@handle)
    invisible(object)
})

#' @rdname get-set-srs
#' @export
setMethod("setSRS",
          signature(object = "RGDAL2LayerGeometry", SRS = "RGDAL2SpatialRef"),
          function(object, SRS)
{
    warning("Cannot set SRS on geometry owned by layer")
    invisible(object)
})

#' @rdname get-set-srs
#' @export
setMethod("setSRS",
          signature(object = "RGDAL2Geometry", SRS = "numeric"),
          function(object, SRS)
{
    setSRS(object, newSRS(paste0("EPSG", SRS, sep = ":")))
})

#' @rdname get-set-srs
#' @export
setMethod("setSRS",
          signature(object = "RGDAL2Geometry", SRS = "character"),
          function(object, SRS)
{
    srs = newSRS(SRS)
    setSRS(object, srs)
})

#' @rdname get-set-srs
#' @export
setMethod("setSRS",
          signature(object = "RGDAL2Dataset", SRS = "RGDAL2SpatialRef"),
          function(object, SRS)
{
    if ( GDALSetProjection(object@handle, getWKT(SRS)) )
        warning("Error setting projection")
    invisible(object)
})

#' @rdname get-set-srs
#' @export
setMethod("setSRS",
          signature(object = "RGDAL2RasterBand", SRS = "RGDAL2SpatialRef"),
          function(object, SRS)
{
    if ( GDALSetProjection(object@dataset@handle, getWKT(SRS)) )
        warning("Error setting projection")
    invisible(object)
})

#' @note
#' Calling \code{setSRS} with \code{SRS = NULL} is a no-op that simply
#' returns the object without effect other than a warning
#' 
#' @rdname get-set-srs
#' @export
setMethod("setSRS",
    signature(object = "ANY", SRS = "NULL"),
    function(object, SRS)
{
    warning("SRS not set; input SRS is NULL")
    object          
})

#' @export
setMethod("reproject",
    signature(object = "RGDAL2Geometry", SRS = "RGDAL2SpatialRef"),
    function(object, SRS)
{
    if ( isEmptySRS(SRS) ) return(object)
    if ( hasSRS(object) )
    {
        x = OGR_G_Clone(object@handle)
        if ( OGR_G_TransformTo(x, SRS@handle) )
            stop("Error reprojecting geometry")
        res = newRGDAL2Geometry(x)
        setSRS(res, SRS)
        res
    }
    else
    {
        setSRS(object, SRS)
        object
    }
})

#' @export
setMethod("reproject",
          signature(object = "RGDAL2Geometry", SRS = "numeric"),
          function(object, SRS)
{
    reproject(object, newSRS(paste0("EPSG", SRS, sep = ":")))
})

#' @export
setMethod("reproject",
          signature(object = "RGDAL2Geometry", SRS = "character"),
          function(object, SRS)
{
    reproject(object, newSRS(SRS))
})

#' @export
setMethod("reproject",
          signature(object = "ANY", SRS = "NULL"),
          function(object, SRS)
{
    warning("Object not reprojected; input SRS is NULL")
    object
})

isGeographic = function(x)
{
    if ( !inherits(x, "RGDAL2SpatialRef") ) x = getSRS(x)
    OSRIsGeographic(x@handle) == 1
}

hasSRS = function(x)
{
    !is.null(getSRS(x))
}

isEmptySRS = function(x)
{
    nchar(getWKT(x)) == 0
}
