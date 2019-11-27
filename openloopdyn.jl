#using PowerDynamics: @DynamicNode
#using Base: @__doc__
#using PowerDynamics: AbstractNode

begin
    @DynamicNode OpenLoopSwingEq(H, D, Ω) begin
        PowerDynamics.MassMatrix(;m_u = true, m_int = [1, 0])
    end begin
        @assert D > 0 "damping (D) should be >0"
        @assert H > 0 "inertia (H) should be >0"
        Ω_H = Ω * 2pi / H
    end [[ω, dω], [c, dc]] begin
        p = real(u * conj(i_c))
        dϕ = ω # dϕ is only a temp variable that Julia should optimize out
        du = u * im * dϕ
        dω = (c - D*ω - p)*Ω_H
        dc = 0
    end
end
