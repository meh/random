rle :: (Eq a) => [a] -> [(Int, a)]
rle [] = []
rle xs = (length $ takeWhile (== value) xs, value) : rle (dropWhile (== value) xs)
  where value = head xs
