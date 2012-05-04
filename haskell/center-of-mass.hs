import System.Environment
import System.IO
import Control.Monad
import Data.List
import Data.List.Split
import Text.Printf
import TypeLevel.NaturalNumber
import Data.Eq.Approximate

type ADouble = AbsolutelyApproximateValue (Digits Five) Double

wrap :: Double -> ADouble
wrap = AbsolutelyApproximateValue
unwrap :: ADouble -> Double
unwrap = unwrapAbsolutelyApproximateValue

type Point    = (ADouble, ADouble, ADouble)
type Velocity = (ADouble, ADouble, ADouble)
type Firefly  = (Point, Velocity)
type Swarm    = [Firefly]
type Universe = (ADouble, Swarm)

time      (n, _) = n
fireflies (_, n) = n

position (n, _) = n
velocity (_, n) = n

x (n, _, _) = n
y (_, n, _) = n
z (_, _, n) = n

getUniverseTimeline :: Universe -> [(ADouble, ADouble)]
getUniverseTimeline u = (map (\ t ->
  (t, distanceFromOrigin $ findCenter (map (step t) (fireflies u)))) [0, 0.1 .. 100.0])
      where distanceFromOrigin (px, py, pz) =
              sqrt $ (0 - px) ** 2 + (0 - py) ** 2 + (0 - pz) ** 2

findMinimumDistanceAndTime :: Universe -> (ADouble, ADouble)
findMinimumDistanceAndTime u = minimumBy (\ a b -> compare (snd a) (snd b)) timeline
  where timeline = getUniverseTimeline u

findCenter :: Swarm -> Point
findCenter ffs = (averageFor x ffs, averageFor y ffs, averageFor z ffs)
  where averageFor which xs = sum (map (which . position) xs) / genericLength xs

step :: ADouble -> Firefly -> Firefly
step t ff = ((next ff t x, next ff t y, next ff t z), velocity ff)
  where next ff t which = which (position ff) + (which (velocity ff)) * t

-- man the harpoons, this shit is ugly
main = do
  argv <- getArgs
  inh <- openFile (argv !! 0) ReadMode
  amount <- hGetLine inh

  forM_ [1 .. read amount :: Int] (\ n -> do
    amount <- hGetLine inh
    ffs <- forM [1 .. read amount :: Int] (\ n -> do
      line <- hGetLine inh

      let (a:b:c:d:e:f:xs) = map (\ n -> wrap (read n :: Double)) (splitOn " " line) in
          return ((a, b, c), (d, e, f)))

    let (t, d) = findMinimumDistanceAndTime (0.0, ffs) in
        printf "Case #%d: %.8f %.8f\n" n (unwrap d) (unwrap t)

    return ())
