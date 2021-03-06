module Util where

import Color exposing (Color)
import Debug
import List
import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3, vec3)
import Ref exposing (Ref)
import Style
import Task exposing (Task)
import WebGL exposing (Triangle)


mod1: Float -> Float
mod1 x = x - toFloat (floor x)

logError : String -> Task x a -> Task x a
logError s t = Task.onError t (Debug.log s >> Task.fail)

applyUpdates : Signal (Ref t) -> Signal (t -> t) -> Signal (Task () ())
applyUpdates r u = Signal.sampleOn u (Signal.map2 (Signal.send << Ref.transform) r u)


colorToVec3 : Color -> Vec3
colorToVec3 =
    let f x = (toFloat x) / 255.0
    in  Color.toRgb >> \c -> vec3 (f c.red) (f c.green) (f c.blue)

type alias WithColorUniforms a = { a
    | midnightColor: Vec3
    , darkColor: Vec3
    , lightColor: Vec3
    , noonColor: Vec3
    , colorStopAngle: Float
    }

addColorUniforms : a -> WithColorUniforms a
addColorUniforms r =
    let c2v = colorToVec3
        -- is there really no multi-field syntax for this?
        r1 = {r  | midnightColor = c2v Style.midnightColor}
        r2 = {r1 | darkColor = c2v Style.darkColor}
        r3 = {r2 | lightColor = c2v Style.lightColor}
        r4 = {r3 | noonColor = c2v Style.noonColor}
        r5 = {r4 | colorStopAngle = Style.colorStopAngle}
    in  r5


squareData : List (Triangle {pos: Vec2})
squareData =
    let vtx x y = {pos = vec2 x y}
        a = vtx -1  1
        b = vtx  1  1
        c = vtx  1 -1
        d = vtx -1 -1
    in  [(a, b, c), (c, d, a)]


divideUnit : Int -> List Float
divideUnit n = List.map (toFloat >> (*) (1 / toFloat n)) [0..n-1]

-- TODO: clean this up
splitAt : Float -> List Float -> List a -> List (List a)
splitAt x0 xvals yvals =
    let pairs = List.map2 (,) xvals yvals
        (left, right) = List.partition (\(x, y) -> x < x0) pairs
    in  [List.map snd left, List.map snd right]
