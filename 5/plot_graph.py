import matplotlib.pyplot as plt
import pandas as pd

data = {
    "pool_size": [200, 200, 200, 20, 20, 20, 200, 200, 200, 20, 20, 20],
    "pool_mode": ["statement", "transaction", "session"] * 4,
    "clients": [100, 100, 100, 100, 100, 100, 1000, 1000, 1000, 1000, 1000, 1000],
    "TPS": [883, 822, 733, 860, 844, 963, 781, 779, 747, 758, 774, 746],
}

df = pd.DataFrame(data)

pool_modes = df["pool_mode"].unique()

tps_min = df["TPS"].min() - 10
tps_max = df["TPS"].max() + 10


fig, axs = plt.subplots(1, 3, figsize=(18, 6))
for i, mode in enumerate(pool_modes):
    subset = df[df["pool_mode"] == mode]
    for pool_size in subset["pool_size"].unique():
        size_data = subset[subset["pool_size"] == pool_size]
        axs[i].plot(
            size_data["clients"],
            size_data["TPS"],
            marker="o",
            linestyle="-" if pool_size == 200 else "--",
            label=f"Pool size: {pool_size}",
        )
    axs[i].set_title(f"{mode.capitalize()} Mode")
    axs[i].set_xlabel("Number of Clients")
    axs[i].set_ylabel("TPS")
    axs[i].set_ylim(tps_min, tps_max)
    axs[i].legend(title="Pool Size")
    axs[i].grid(True)

plt.tight_layout()
plt.show()
