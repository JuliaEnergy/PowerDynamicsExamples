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
The problem in PowerDynamics is that each node function
has only access to it's local variables
but we need global access. To achieve this, we wrap
the PowerDynamics RHS together with another function
that gets the whole "x" as an input.
"""

"""
x' = f(x, u)

-> RHS created by PowerDynamics
One variable, here x[3] is the control "u" and not changed in this function.
In PowerDynamics, they should probably be internal variables of nodes.
Then, the total RHS created by PowerDynamics is the open loop function.
"""
function open_loop!(dx, x, p, t)
    dx[1] = x[2]
    dx[2] = x[3] - p.α * x[2] - p.K * sin(x[1])
    dx[3] = 0.
    nothing
end

"""
u = k * y

This function determines the "u". Note that here we have access to the whole
state "x", can calculate Pmeas etc., and hence determine the control input for
all nodes.

This formulation requires a mass matrix.
"""
function dae_controller!(dx, x, p, t)
    dx[3] = x[3] - p.k_p * t^2
    nothing
end

"""
u' = k_I y

As above but the control law is formulated as a differential equation.
No mass matrix needed.
"""
function ode_controller!(dx, x, p, t)
    dx[3] = 1//2 * p.k_p * t
    nothing
end

"""
To close the loop, we need to wrap open loop and controller
in a function with the right signature for DifferentialEquations.jl.
"""
function dae_wrapper!(dx, x, p, t)
    open_loop!(dx, x, p, t)
    dae_controller!(dx, x, p, t)
    nothing
end

function ode_wrapper!(dx, x, p, t)
    open_loop!(dx, x, p, t)
    ode_controller!(dx, dx, p, t) # (dx, dx, p, t) ??
    nothing
end

d = 3 # dimension
p = SytemPars(1., 8., 0.1, 2I(d), .5)

u0 = randn(d)
u0[end] = 0

dae_closed_loop! = ODEFunction(dae_wrapper!, mass_matrix=Diagonal([1, 1, 0]))
ode_closed_loop! = ODEFunction(ode_wrapper!)

ode = ODEProblem(ode_closed_loop!, u0, (0., 100.), p)
dae = ODEProblem(dae_closed_loop!, u0, (0., 100.), p)

ode_sol = solve(ode, Rodas4(), dt=0.001)

plot(ode_sol, vars=2)

dae_sol = solve(dae, Rodas4(), dt=0.001)

plot!(dae_sol, vars=2)
