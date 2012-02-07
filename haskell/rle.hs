import List

encode :: (Eq a) => [a] -> [(Int, a)]
encode = map (\ xs -> (length xs, head xs)) . group

decode :: [(Int, a)] -> [a]
decode = concatMap (uncurry replicate)
