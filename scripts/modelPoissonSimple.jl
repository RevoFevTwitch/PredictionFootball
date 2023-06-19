using Statistics, LinearAlgebra
using HTTP, CSV, DataFrames
using StatsPlots
using Turing
using ReverseDiff
Turing.setadbackend(:reversediff)

# Dataset de 538:
df = CSV.read(HTTP.get("https://projects.fivethirtyeight.com/soccer-api/club/spi_matches.csv").body, DataFrame)
filter!(:league_id => (x -> x == 2411), df) # On garde seulement la Premier League
filter!(:season => (x -> x == 2022), df) # et seulement la saion 2022-2023

# Variables utilitaires:
nMatches = size(df, 1)
teams = unique(df.team1)
nTeams = size(teams, 1)
dict = Dict(teams .=> 1:nTeams)
df[!, :teamIndex1] = [dict[team] for team in df.team1]
df[!, :teamIndex2] = [dict[team] for team in df.team2]

# Modèle:
@model function footballMatch(teamsHome, teamsAway, scoresHome, scoresAway)

    # Hyperpriors (incertitude quant aux croyances à priori):
    μ_att ~ Normal(0.0, 0.1)
    μ_def ~ Normal(0.0, 0.1)
    σ_att ~ Exponential(1)
    σ_def ~ Exponential(1)

    # Priors (croyances à priori):
    att ~ filldist(Normal(μ_att, σ_att), nTeams)
    def ~ filldist(Normal(μ_def, σ_def), nTeams)
    dom ~ Normal(0.0, 1.0)

    # Compensation pour contraindre att et def autour de 0:
    comp = mean(att) + mean(def)

    # Containers pour nos variables θ:
    logθHome = Vector{Real}(undef, nMatches)
    logθ_away = Vector{Real}(undef, nMatches)

    # Modèle de match:
    for i in 1:nMatches
        logθHome[i] = att[teamsHome[i]] + def[teamsAway[i]] + dom + comp
        logθ_away[i] = att[teamsAway[i]] + def[teamsHome[i]] + comp

        scoresHome[i] ~ LogPoisson(logθHome[i])
        scoresAway[i] ~ LogPoisson(logθ_away[i])
    end
end

# Création du modèle à partir des données, puis estimation:
epl = footballMatch(df.teamIndex1, df.teamIndex2, df.score1, df.score2)
results = sample(epl, NUTS(), 3000)

# Extraire les résultats:
att_post = group(results, :att)
def_post = group(results, :def)
dom_post = group(results, :dom)

# Tableau des stats par équipes
statsEquipe = DataFrame()
statsEquipe[!, :team] = teams
abbr_teams = [team[1:3] for team in teams]
abbr_teams[findall(x -> x == "Manchester United", teams)] .= "MNU"
abbr_teams[findall(x -> x == "Manchester City", teams)] .= "MNC"
statsEquipe[!, :abbrTeam] = abbr_teams

statsEquipe[!, :μ_att] = [mean(results, "att[$i]") for i in 1:nTeams]
statsEquipe[!, :μ_def] = [mean(results, "def[$i]") for i in 1:nTeams]
statsEquipe[!, :σ_att] = [std(att_post[:, i, :]) for i in 1:nTeams]
statsEquipe[!, :σ_def] = [std(def_post[:, i, :]) for i in 1:nTeams]

# Simuler des matchs:
function simulatePoissonMatches(attHome, defHome, attAway, defAway, dom; nMatches=100)
    logθHome = attHome + defAway + dom
    logθAway = attAway + defHome

    scoresHome = vcat(rand.(LogPoisson.(logθHome), nMatches)...)
    scoresAway = vcat(rand.(LogPoisson.(logθAway), nMatches)...)

    return scoresHome, scoresAway
end

# Calculer la prédiction finale:
function predictMatch(teamHome, teamAway; model="Poisson")
    attHome = results["att[$(dict[teamHome])]"].data
    defHome = results["def[$(dict[teamHome])]"].data
    attAway = results["att[$(dict[teamAway])]"].data
    defAway = results["def[$(dict[teamAway])]"].data

    dom = results["dom"].data

    scoresHome, scoresAway = simulatePoissonMatches(attHome, defHome, attAway, defAway, dom)

    # Probabilités:
    nMatchesSimules = size(scoresHome, 1)
    prob1 = sum(scoresHome .> scoresAway) ./ nMatchesSimules
    probTie = sum(scoresHome .== scoresAway) ./ nMatchesSimules
    prob2 = sum(scoresHome .< scoresAway) ./ nMatchesSimules
    probOver25 = count(>(2.5), scoresHome + scoresAway) ./ nMatchesSimules
    probUnder25 = count(<(2.5), scoresHome + scoresAway) ./ nMatchesSimules

    # Matrice des scores:
    simulatedScores = hcat(scoresHome, scoresAway)
    scoreMatrix = zeros(maximum(simulatedScores, dims=1)[1]+1, maximum(simulatedScores, dims=1)[2]+1)
    for i in axes(scoreMatrix)[1], j in axes(scoreMatrix)[2]
        scoreMatrix[i, j] = sum([row == [i-1, j-1] for row in eachrow(simulatedScores)])
    end
    scoreMatrix =  round.(100 * scoreMatrix / nMatchesSimules, digits=1)

    # Visualisation de la prédiction:
    f = heatmap(0:1:size(scoreMatrix, 2)-1, 0:1:size(scoreMatrix, 1)-1, scoreMatrix, xlabel="$teamAway (Away)", ylabel="$teamHome (Home)", legend=false)
    for (i, x) in enumerate(scoreMatrix)
        if x > 0.0
            row, col = divrem(i - 1, size(scoreMatrix, 1))
            annotate!(row, col, text(string(x), :gray, :centered))
        end
    end
    xticks!(0:1:size(scoreMatrix, 2)-1)
    yticks!(0:1:size(scoreMatrix, 1)-1)
    title!("$teamHome v. $teamAway \n Home Win: $(round(100 * prob1, digits=1))%; Draw: $(round(100 * probTie, digits=1))%; Away Win: $(round(100 * prob2, digits=1))% \n")
    display(f)

    return prob1, probTie, prob2, probOver25, probUnder25, scoreMatrix
end

predictMatch("Fulham", "Liverpool") # Une prédiction au hasard