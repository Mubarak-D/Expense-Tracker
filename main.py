import sys


def read_line():
    return sys.stdin.readline()


def sum_powers(values, index):
    if index >= len(values):
        return 0
    current = values[index]
    contribution = current ** 4 if current <= 0 else 0
    return contribution + sum_powers(values, index + 1)


def solve_case(declared_count, tokens):
    if len(tokens) != declared_count:
        return -1
    return sum_powers(tokens, 0)


def collect_results(remaining, acc):
    if remaining == 0:
        return acc
    declared_count = int(read_line().strip())
    tokens = tuple(map(int, read_line().split()))
    acc.append(solve_case(declared_count, tokens))
    return collect_results(remaining - 1, acc)


def render(results, index, chunks):
    if index >= len(results):
        return chunks
    chunks.append(str(results[index]))
    return render(results, index + 1, chunks)


def main():
    n = int(read_line().strip())
    results = collect_results(n, [])
    sys.stdout.write("\n".join(render(results, 0, [])))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
