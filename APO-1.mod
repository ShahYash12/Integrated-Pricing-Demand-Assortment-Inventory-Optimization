# ============================================================
# APO-1 Linearized MILP (Assortment + Pricing + Inventory)
# Deterministic Maximum-Surplus Choice with customer segments
# Linearization:
#   g[i,j,t] = p[j,t] * x[i,j,t]
#   w[j,t]   = p[j,t] * z[j]
# ============================================================

set PROD;                 # products j = 1..n
set SEG;                  # customer segments i = 1..m
set PER ordered;          # periods t = 1..T

# explicit no-purchase option
set CHOICE := PROD union {0};

# -------- Parameters --------
param s{SEG} >= 0;        # segment sizes

# reservation prices (WTP); define alpha[i,0,t] = 0
param alpha{SEG,CHOICE,PER} >= 0;

param c{PROD,PER} >= 0;   # unit procurement cost
param h{PROD,PER} >= 0;   # holding cost
param K{PROD,PER} >= 0;   # fixed ordering cost
param f{PROD}     >= 0;   # fixed assortment cost

# Upper bound on price p[j,t] (usually max_i alpha[i,j,t])
param p_ub{PROD,PER} >= 0;

# Total market size (used for safe order cap)
param S_total := sum{i in SEG} s[i];

# -------- Decision Variables --------
var z{PROD} binary;               # offer product j (assortment)
var y{PROD,PER} binary;           # place order/setup for j in t

var p{PROD,PER} >= 0;             # price
var u{PROD,PER} >= 0;             # order quantity
var I{PROD,PER} >= 0;             # end inventory
var d{PROD,PER} >= 0;             # demand

var x{SEG,CHOICE,PER} binary;     # segment choice (incl. 0=no purchase)

# Linearization vars:
var g{SEG,PROD,PER} >= 0;         # g[i,j,t] = p[j,t] * x[i,j,t]
var w{PROD,PER}     >= 0;         # w[j,t]   = p[j,t] * z[j]

# -------- Objective (linearized revenue) --------
# Revenue in period t for product j:
#   p[j,t] * d[j,t] = p[j,t] * sum_i s[i] x[i,j,t]
# Linearize with g: sum_i s[i] * g[i,j,t]
maximize Profit:
    sum{t in PER, j in PROD} (
        sum{i in SEG} s[i] * g[i,j,t]   # revenue
        - K[j,t] * y[j,t]
        - c[j,t] * u[j,t]
        - h[j,t] * I[j,t]
    )
  - sum{j in PROD} f[j] * z[j];

# ============================================================
# Constraints
# ============================================================

# 1) One choice per segment per period (incl. no purchase 0)
subject to SingleChoice{i in SEG, t in PER}:
    sum{j in CHOICE} x[i,j,t] = 1;

# 2) Choice requires offering
subject to ChoiceRequiresOffering{i in SEG, j in PROD, t in PER}:
    x[i,j,t] <= z[j];

# 3) Setup requires offering
subject to SetupRequiresOffering{j in PROD, t in PER}:
    y[j,t] <= z[j];

# 4) Demand definition
subject to DemandDef{j in PROD, t in PER}:
    d[j,t] = sum{i in SEG} s[i] * x[i,j,t];

# 5) Inventory balance
subject to InvBal_First{j in PROD, t in first(PER)}:
    I[j,t] = u[j,t] - d[j,t];

subject to InvBal{j in PROD, t in PER: ord(t) > 1}:
    I[j,t] = I[j,prev(t)] + u[j,t] - d[j,t];

# 6) End inventory zero (as in the paper’s horizon setup)
subject to EndInvZero{j in PROD, t in last(PER)}:
    I[j,t] = 0;

# 7) Price bounds + "price only if offered"
subject to PriceUpper{j in PROD, t in PER}:
    p[j,t] <= p_ub[j,t] * z[j];

# 8) Order cap / activation (safe bound)
subject to OrderCap{j in PROD, t in PER}:
    u[j,t] <= y[j,t] * ((card(PER) - ord(t) + 1) * S_total);

# ------------------------------------------------------------
# Linearization: g[i,j,t] = p[j,t] * x[i,j,t]
# Use standard McCormick/Big-M constraints with p_ub
# ------------------------------------------------------------
subject to g_up1{i in SEG, j in PROD, t in PER}:
    g[i,j,t] <= p_ub[j,t] * x[i,j,t];

subject to g_up2{i in SEG, j in PROD, t in PER}:
    g[i,j,t] <= p[j,t];

subject to g_low{i in SEG, j in PROD, t in PER}:
    g[i,j,t] >= p[j,t] - p_ub[j,t] * (1 - x[i,j,t]);

# ------------------------------------------------------------
# Linearization: w[j,t] = p[j,t] * z[j]
# ------------------------------------------------------------
subject to w_up1{j in PROD, t in PER}:
    w[j,t] <= p_ub[j,t] * z[j];

subject to w_up2{j in PROD, t in PER}:
    w[j,t] <= p[j,t];

subject to w_low{j in PROD, t in PER}:
    w[j,t] >= p[j,t] - p_ub[j,t] * (1 - z[j]);

# ------------------------------------------------------------
# Maximum-surplus choice constraints (linearized)
# Define "chosen surplus" for segment i in period t as:
#   U_it = sum_{k in PROD} alpha[i,k,t] x[i,k,t] - sum_{k in PROD} g[i,k,t]
# (no-purchase option has alpha=0, price=0)
# Then enforce:
#   U_it >= alpha[i,j,t] z[j] - w[j,t]  for all j in PROD
# And:
#   U_it >= 0  (non-negative utility)
# ------------------------------------------------------------

# Non-negative utility:
subject to NonNegUtility{i in SEG, t in PER}:
    sum{k in PROD} alpha[i,k,t] * x[i,k,t] - sum{k in PROD} g[i,k,t] >= 0;

# Max-surplus dominance for every offered product j
subject to UtilityChoice{i in SEG, t in PER, j in PROD}:
    sum{k in PROD} alpha[i,k,t] * x[i,k,t] - sum{k in PROD} g[i,k,t]
    >= alpha[i,j,t] * z[j] - w[j,t];

# (Optional) You may also fix alpha[i,0,t]=0 in data.