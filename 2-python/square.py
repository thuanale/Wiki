import turtle
class settings():
    def screen():
        screen = turtle.Screen()
        screen.title("Welcome to the drawing")
        
    def pen():
        pen = turtle.Turtle()
        pen.color("red")
        

wn=settings.screen()
pen=settings.pen()

def draw_poly(t, n, sz):
    poly_angle=360/n
    for i in range(n):
        t.forward(sz)
        t.left(poly_angle)
    
def draw_polies(t, n, sz, m):
    rotate_angle=360/m
    for i in range(m):
        draw_poly(t,n, sz)
        t.left(rotate_angle)
        #sz+=20
        
draw_polies(pen, 4, 100, 40)
wn.mainloop()
