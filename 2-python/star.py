import turtle

wn = turtle.Screen()
wn.bgcolor("red")

star = turtle.Turtle()
star.color("yellow","yellow")
star.begin_fill()
size=100

while True:
    star.forward(size)
    star.left(-144)
    if abs(star.pos()) < 1:
        star.hideturtle()
        break

star.end_fill()

wn.mainloop()
