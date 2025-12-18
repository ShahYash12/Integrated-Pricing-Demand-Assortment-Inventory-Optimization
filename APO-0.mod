# ============================================================
# Integrated Assortment-Pricing-Inventory (APO-0 MINLP)
# Deterministic Maximum-Surplus Choice with customer segments
# Ghoniem & Maddah (Omega, 2015) - MINLP style
# ============================================================

# ---------- Sets ----------
set PROD;                 # Products j = 1..n (real products)
set SEG;                  # Customer segments i = 1..m
set PER ordered;          # Periods t = 1..T (ordered is useful for prev/next)

# Add an explicit "no-purchase" option as product 0:
set CHOICE := PROD union {0};

# ---------- Parameters ----------
param s{SEG} >= 0;        # segment size (customers in segment i)

param alpha{SEG,CHOICE,PER} >= 0; 
# reservation prices (willingness to pay) for segment i, choice j, period t
# For no-purchase option j=0, set alpha[i,0,t] = 0

param c{PROD,PER}  >= 0;  # unit ordering/procurement cost
param h{PROD,PER}  >= 0;  # holding cost per unit end inventory
param K{PROD,PER}  >= 0;  # fixed ordering/setup cost if ordering in period t
param f{PROD}      >= 0;  # fixed assortment cost if product is carried

# Big-M for choice constraints (should be "large enough")
# Safe default: max reservation price range; you can tighten if you want.
param M >= 0;

# Upper bound on price per product-period (helps solver)
# Typically max over segments of alpha[i,j,t]
param p_ub{PROD,PER} >= 0;

# Total market size (used for capacity bounds)
param S_total := sum{i in SEG} s[i];

# ---------- Decision Variables ----------
# Assortment: offer product j at all?
var z{PROD} binary;

# Order setup: place an order for product j in period t?
var y{PROD,PER} binary;

# Price decision (no-purchase option has implicit price = 0)
var p{PROD,PER} >= 0;

# Order quantity
var u{PROD,PER} >= 0;

# End-of-period inventory
var I{PROD,PER} >= 0;

# Segment choice: x[i,j,t] = 1 if segment i chooses option j in period t
var x{SEG,CHOICE,PER} binary;

# Derived demand per product-period
var d{PROD,PER} >= 0;


# ============================================================
# Objective: maximize total profit over horizon
# sum_t sum_j (p_jt*d_jt - K_jt*y_jt - c_jt*u_jt - h_jt*I_jt) - sum_j f_j*z_j
# ============================================================
maximize Profit:
    sum{t in PER, j in PROD} ( p[j,t]*d[j,t] - K[j,t]*y[j,t] - c[j,t]*u[j,t] - h[j,t]*I[j,t] )
  - sum{j in PROD} f[j]*z[j];


# ============================================================
# Constraints
# ============================================================

# ---- 1) Each segment makes exactly one choice per period (incl. no-purchase option 0)
subject to SingleChoice{i in SEG, t in PER}:
    sum{j in CHOICE} x[i,j,t] = 1;

# ---- 2) Choice requires offering: if product not offered, cannot be chosen
subject to ChoiceRequiresOffering{i in SEG, j in PROD, t in PER}:
    x[i,j,t] <= z[j];

# (No-purchase option 0 is always available; no constraint needed)

# ---- 3) Setup requires offering: cannot order if not offered
subject to SetupRequiresOffering{j in PROD, t in PER}:
    y[j,t] <= z[j];

# ---- 4) Demand definition: d_jt = sum_i s_i * x_ijt
subject to DemandDef{j in PROD, t in PER}:
    d[j,t] = sum{i in SEG} s[i]*x[i,j,t];

# ---- 5) Inventory balance: I_jt = I_j,t-1 + u_jt - d_jt
# For first period, assume starting inventory = 0
subject to InvBal_First{j in PROD, t in first(PER)}:
    I[j,t] = u[j,t] - d[j,t];

subject to InvBal{j in PROD, t in PER: ord(t) > 1}:
    I[j,t] = I[j, prev(t)] + u[j,t] - d[j,t];

# ---- 6) No initial/final inventory (common in the paper's horizon modeling)
# Initial already enforced as 0 via InvBal_First.
subject to EndInvZero{j in PROD, t in last(PER)}:
    I[j,t] = 0;

# ---- 7) Price upper bound: if not offered, p=0; if offered, bounded by p_ub
subject to PriceUpper{j in PROD, t in PER}:
    p[j,t] <= p_ub[j,t]*z[j];

# ---- 8) Ordering capacity / activation:
# If y=0 then u=0. If y=1, bound u by remaining horizon demand upper bound.
# A simple safe upper bound: remaining periods * total segment size
subject to OrderCap{j in PROD, t in PER}:
    u[j,t] <= y[j,t] * ( (card(PER) - ord(t) + 1) * S_total );

# ---- 9) Non-negative utility (chosen option must give >= 0 surplus)
# Uses chosen surplus = sum_k (alpha - price)*x
# This is nonlinear because of p* x in the sum.
subject to NonNegUtility{i in SEG, t in PER}:
    sum{k in PROD} (alpha[i,k,t] - p[k,t]) * x[i,k,t] + alpha[i,0,t] * x[i,0,t] >= 0;

# ---- 10) Max-surplus choice condition (chosen surplus >= surplus of any offered product)
# The chosen surplus is the LHS (with x); RHS is candidate product j surplus if offered.
# This is nonlinear due to p* x on LHS.
subject to UtilityChoice{i in SEG, t in PER, j in PROD}:
    sum{k in PROD} (alpha[i,k,t] - p[k,t]) * x[i,k,t] + alpha[i,0,t]*x[i,0,t]
    >= (alpha[i,j,t] - p[j,t]) * z[j];

# Optional tightening: prevent choosing a product if price exceeds its reservation price
# (Often implied by NonNeg + UtilityChoice, but can help numerically)
subject to PriceNotAboveReservation{i in SEG, j in PROD, t in PER}:
    p[j,t] <= alpha[i,j,t] + M*(1 - x[i,j,t]);

# ---- Domain note: x,y,z are binary, others nonnegative already declared