using DifferentialEquations
using LinearAlgebra
using Plots

struct SytemPars
    P
    K
    α
    C
    k_p
end

"""
x' = f(x, u)
"""
function open_loop!(dx, x, p, t)
    dx[1] = x[2]
    dx[2] = x[3] - p.α * x[2] - p.K * sin(x[1])
    dx[3] = 0.
    nothing
end

"""
y = g(x), e.g. y = Cx
"""
function observation!(dx, x, p, t)
    dx .= p.C * x
    nothing
end

"""
u' = k_I y
"""
function Icontroller!(dx, x, p, t)
    dx[3] = p.k_I * t
    nothing
end

function wrapper!(dx, x, p, t)
    open_loop!(dx, x, p, t)
    observation!(dx, x, p, t)
    Pcontroller!(dx, x, p, t)
    nothing
end

function wrapper(x, p, t)
    y = open_loop(x, p, t)
    return controller(y, p, t)
end

d = 3
p = SytemPars(1., 8., 0.1, 2I(d), 2.)

u0 = rand(3)

closed_loop! = ODEFunction(wrapper!, mass_matrix=Diagonal([1, 1, 0]))

ode = ODEProblem(closed_loop!, u0, (0., 1.), p)

sol = solve(ode, Rodas4(), dt=0.01)

plot(sol, vars=2:3)




ode2 = ODEProblem(wrapper, u0, (0., 1.), p)

sol2 = solve(ode2, Rodas4())

plot(sol2, vars=1:2)
