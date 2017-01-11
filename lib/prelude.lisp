(import base (defun defmacro progn for while if when unless and or with xpcall
              get-idx set-idx! format print! pretty error! empty-struct gensym
              traceback
              == ~= < <= > >= + - * / % ^ .. !))

(import binders ())
(import list ())
(import types ())
(import partial ())
(import table ())

(defun fail (msg) (error! msg 0))

(defun between? (val min max) (and (>= val min) (<= val max)))

(defun symbol->string (x) (if (symbol? x) (get-idx x "contents") nil))
(defun bool->string (x) (if x "true" "false"))

(define-native number->string)

(defun /= (x y) (~= x y))
(defun = (x y) (== x y))

(defmacro case (x &cases)
  (let* ((name (gensym))
         (transform-case (lambda (case)
                           (if (list? case)
                             (if (list? (car case))
                               `((,@(car case) ,name) ,@(cdr case))
                               `(,(car case) ,@(cdr case)))
                             `(true)))))
    `((lambda (,name) (cond ,@(map transform-case cases))) ,x)))

(defun succ (x) (+ 1 x))
(defun pred (x) (- x 1))

(defmacro inc! (x) `(set! ,x (+ ,x 1)))
(defmacro dec! (x) `(set! ,x (- ,x 1)))
