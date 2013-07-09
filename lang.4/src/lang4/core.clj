(ns lang4.core
  (:require [instaparse.core :as insta]))

(def go-file
  (insta/parser (slurp "go-parser.txt")))

(defn foo
  "I don't do a whole lot."
  [filename]
  (def text (slurp filename))
  (println (time (go-file text))))

