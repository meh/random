import System (getArgs)
import List (find)
import Char (digitToInt)

euler :: Int -> Integer

euler 1 = sum [x | x <- [1 .. 1000 - 1], x `mod` 3 == 0 || x `mod` 5 == 0]

euler 2 = sum [x | x <- takeWhile (< 4000000) fibonacci, even x]
  where
    fibonacci :: [Integer]
    fibonacci = 0 : 1 : zipWith (+) fibonacci (tail fibonacci)

euler 3 = toInteger $ maximum $ filter (isPrime) (factorsOf 600851475143)
  where
    factorsOf :: Int -> [Int]
    factorsOf x = filter (\ n -> x `mod` n == 0) [2 .. floor $ sqrt $ fromIntegral x]

    isPrime :: Int -> Bool
    isPrime x = all (\ n -> x `mod` n /= 0) (takeWhile (< x) [2..])

euler 4 = toInteger $ maximum $ filter (isPalindromic) [x * y | x <- [111 .. 999], y <- [111 .. 999]]
  where
    isPalindromic :: Int -> Bool
    isPalindromic x = (show x) == reverse (show x)

euler 5 = toInteger $ fromJust $ find evenlyDivisible [1..]
  where
    evenlyDivisible :: Int -> Bool
    evenlyDivisible x = all (\ n -> x `mod` n == 0) [1 .. 20]

    fromJust (Just x) = x

euler 6 = (squareOfSum [1 .. 100]) - (sumOfSquares [1 .. 100])
  where
    sumOfSquares :: [Int] -> Integer
    sumOfSquares xs = toInteger $ sum $ map (\ n -> n ^ 2) xs

    squareOfSum :: [Int] -> Integer
    squareOfSum xs = toInteger $ (sum xs) ^ 2

euler 7 = toInteger $ primes !! 10001
  where
    primes = [x | x <- [1 ..], all (\ n -> x `mod` n /= 0) [2 .. x - 1]]

euler 8 = toInteger $ maximum $ fiveDigitProduct hugeNumber
  where
    fiveDigitProduct :: String -> [Int]
    fiveDigitProduct [] = []
    fiveDigitProduct xs = (product (map digitToInt (take 5 xs))) : fiveDigitProduct (tail xs)

    hugeNumber =
      "73167176531330624919225119674426574742355349194934" ++
      "96983520312774506326239578318016984801869478851843" ++
      "8586156078911294949545950173795833195285320880551d" ++
      "1254069874715852386305071569329096329522744304355d" ++
      "6689664895044524452316173185640309871112172238311d" ++
      "6222989342338030813533627661428280644448664523874d" ++
      "3035890729629049156044077239071381051585930796086d" ++
      "7017242712188399879790879227492190169972088809377d" ++
      "6572733300105336788122023542180975125454059475224d" ++
      "5258490771167055601360483958644670632441572215539d" ++
      "5369781797784617406495514929086256932197846862248d" ++
      "8397224137565705605749026140797296865241453510047d" ++
      "8216637048440319989000889524345065854122758866688d" ++
      "1642717147992444292823086346567481391912316282458d" ++
      "1786645835912456652947654568284891288314260769004d" ++
      "2421902267105562632111110937054421750694165896040d" ++
      "0719840385096245544436298123098787992724428490918d" ++
      "8458015616609791913387549920052406368991256071760d" ++
      "0588611646710940507754100225698315520005593572972d" ++
      "71636269561882670428252483600823257530420752963450"

euler n = error $ "no euler problem solved for " ++ show n

main = do
  args <- getArgs

  mapM_ (\ arg -> putStrLn $ arg ++ ": " ++ show (euler (read arg :: Int))) args
