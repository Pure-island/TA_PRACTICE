using UnityEngine;

namespace TA_Practice.Chapter02
{
    public sealed class QuaternionLookDemo : MonoBehaviour
    {
        [SerializeField] private Transform target;
        [SerializeField] private float degreesPerSecond = 180f;
        [SerializeField] private bool useSlerp;
        [SerializeField] private float slerpSpeed = 5f;
        [SerializeField] private bool keepRotationFlat = true;
        [SerializeField] private bool logValues;

        private void Update()
        {
            if (target == null)
            {
                return;
            }

            Vector3 toTarget = target.position - transform.position;
            if (toTarget.sqrMagnitude <= 0.0001f)
            {
                return;
            }

            Quaternion targetRotation = keepRotationFlat
                ? QuaternionMathUtility.GetFlatLookRotation(transform.position, target.position)
                : Quaternion.LookRotation(toTarget.normalized, Vector3.up);

            transform.rotation = useSlerp
                ? QuaternionMathUtility.SlerpBySpeed(transform.rotation, targetRotation, slerpSpeed, Time.deltaTime)
                : QuaternionMathUtility.RotateTowards(transform.rotation, targetRotation, degreesPerSecond, Time.deltaTime);

            Debug.DrawRay(transform.position, transform.forward, Color.blue);
            Debug.DrawLine(transform.position, target.position, Color.yellow);

            if (logValues)
            {
                float angle = Quaternion.Angle(transform.rotation, targetRotation);
                Debug.Log($"Target rotation: {targetRotation.eulerAngles}, Remaining angle: {angle:F2}", this);
                logValues = false;
            }
        }

        private void OnDrawGizmosSelected()
        {
            if (target == null)
            {
                return;
            }

            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(target.position, 0.2f);
        }
    }
}
