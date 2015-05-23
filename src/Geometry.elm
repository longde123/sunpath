module Geometry where

import LocalTime exposing (LocalTime)
import Math.Vector3 as V3 exposing (Vec3, vec3)
import Time exposing (Time)


type alias Location = Vec3


mod1: Float -> Float
mod1 x = x - toFloat (floor x)


-- (0, 0) -> (1, 0, 0)
fromLatLong : Float -> Float -> Location
fromLatLong lat long =
    let r = cos lat
    in  vec3 (r * (cos long)) (r * (sin long)) (sin lat)

toLatLong : Location -> (Float, Float)
toLatLong v = (asin (V3.getZ v), atan2 (V3.getY v) (V3.getX v))


-- great circle path as a function [0, 0]
greatCircle : Location -> Location -> Float -> Location
greatCircle a b x = if a == b then a else
    let c = V3.normalize (V3.sub b (V3.scale (V3.dot a b) a))
        m = x * acos (V3.dot a b)
    in  V3.add (V3.scale (cos m) a) (V3.scale (sin m) c)


-- latitude at which the sun is directly overhead (annual cycle)
solarDeclination : Time -> Float
solarDeclination t =
    let
        summerSolstice2015 = 1434904680 * Time.second
        years = (t - summerSolstice2015) / (Time.hour * 24 * 365)
    in
        degrees 23.44 * cos (turns years)

-- longitude at which the sun is directly overhead (daily cycle)
solarNoonLongitude : Time -> Float
solarNoonLongitude t =
    let days = (Time.inSeconds t) / 86400
    in  turns (0.5 - mod1 days)

-- location at which the sun is directly overhead
sunDirection : Time -> Location
sunDirection t = fromLatLong (solarDeclination t) (solarNoonLongitude t)

-- angle of the sun above the horizon
sunAltitude : Location -> Time -> Float
sunAltitude pos t =
    (degrees 90) - acos (V3.dot pos (sunDirection t))


-- longitude -> actual time -> apparent time of day as a float in [0, 1]
solarTimeOfDay : Float -> Time -> Float
solarTimeOfDay long t =
    let longDiff = long - solarNoonLongitude t
    in  mod1 (0.5 + longDiff / (turns 1))

-- longitude -> actual time -> local solar time (discontinuous across date line)
apparentTime : Float -> Time -> LocalTime
apparentTime long t =
    -- TODO make this clearer
    let oneDay = Time.hour * 24
        days = t / oneDay
        dayAtLong0 = floor days
        todAtLong0 = mod1 days
        longTurns = mod1 (long / (turns 1))
        dateOffset = floor (longTurns + todAtLong0) - floor (2 * longTurns)
    in  LocalTime.fromTime (LocalTime.utc) (oneDay * (
                toFloat (dayAtLong0 + dateOffset) + (solarTimeOfDay long t)
            ))
