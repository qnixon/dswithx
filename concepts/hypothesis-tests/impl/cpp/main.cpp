// Exact two-sided permutation test for a difference in means, using only the
// C++ standard library.
//
// If compost made no difference, the "compost" and "control" labels are
// arbitrary, and any 8 of the 16 plants could have carried the compost label.
// We try every one of those splits and count how many give a difference at
// least as large as the one we observed. That fraction is the p-value.

#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <numeric>
#include <print>
#include <stdexcept>
#include <string>
#include <vector>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }

    // Read group,grams lines. Controls come first in the file, then compost.
    std::ifstream file(argv[1]);
    std::string line;
    std::getline(file, line);  // skip the header
    std::vector<long> control, compost;
    while (std::getline(file, line)) {
        auto comma = line.find(',');
        if (comma == std::string::npos) {
            continue;
        }
        long grams = std::stol(line.substr(comma + 1));
        (line.substr(0, comma) == "compost" ? compost : control).push_back(grams);
    }
    if (compost.empty() || compost.size() != control.size()) {
        throw std::runtime_error("need two groups of equal size");
    }

    std::vector<long> plants = control;
    plants.insert(plants.end(), compost.begin(), compost.end());
    long control_sum = std::reduce(control.begin(), control.end(), 0L);
    long compost_sum = std::reduce(compost.begin(), compost.end(), 0L);
    long total = control_sum + compost_sum;

    // Both groups have the same size, so comparing totals is the same as
    // comparing means, and totals stay whole numbers: no floating-point
    // near-ties.
    long observed = compost_sum - control_sum;

    // A mask of 0s and 1s, one per plant: 1 means "labeled compost". It
    // starts sorted, all 0s then all 1s, and std::next_permutation steps it
    // through every distinct arrangement once, returning false after the last.
    std::vector<int> mask(plants.size(), 0);
    std::fill(mask.begin() + control.size(), mask.end(), 1);
    long splits = 0, as_extreme = 0;
    do {
        // transform_reduce multiplies each plant by its 0 or 1 and adds them up.
        long chosen = std::transform_reduce(plants.begin(), plants.end(), mask.begin(), 0L);
        long difference = chosen - (total - chosen);
        splits++;
        if (std::labs(difference) >= std::labs(observed)) {  // two-sided
            as_extreme++;
        }
    } while (std::next_permutation(mask.begin(), mask.end()));

    double n = static_cast<double>(compost.size());
    std::println("control_count {}", control.size());
    std::println("compost_count {}", compost.size());
    std::println("control_mean {:.6f}", control_sum / n);
    std::println("compost_mean {:.6f}", compost_sum / n);
    std::println("observed_difference {:.6f}", observed / n);
    std::println("splits {}", splits);
    std::println("as_extreme {}", as_extreme);
    std::println("p_value {:.6f}", static_cast<double>(as_extreme) / splits);
}
