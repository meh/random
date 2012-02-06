rle :: (Eq a) => [a] -> [(Int, a)]
rle [] = []
rle xs = (piece xs) : rle (tail' xs)
  where
    tail' xs = let value = head xs in dropWhile (== value) xs
    piece xs =
      let value = head xs
          number = length $ takeWhile (== value) xs
      in (number, value)
