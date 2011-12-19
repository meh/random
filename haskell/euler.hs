import System (getArgs)
import List (find)

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

euler n = error $ "no euler problem solved for " ++ show n

main = do
  args <- getArgs

  mapM_ (\ arg -> putStrLn $ arg ++ ": " ++ show (euler (read arg :: Int))) args
